#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define WIDTH 50
#define HEIGHT 30
#define DENSITY 0.2
#define CELL_COUNT (WIDTH * HEIGHT)

static volatile sig_atomic_t running = 1;

static const char *kernelSource =
"#define WIDTH 50\n"
"#define HEIGHT 30\n"
"__kernel void next_generation(__global const uchar *grid, __global uchar *next) {\n"
"  int id = get_global_id(0);\n"
"  int x = id % WIDTH;\n"
"  int y = id / WIDTH;\n"
"  int count = 0;\n"
"  for (int dy = -1; dy <= 1; dy++) {\n"
"    for (int dx = -1; dx <= 1; dx++) {\n"
"      if (dx == 0 && dy == 0) continue;\n"
"      int nx = (x + dx + WIDTH) % WIDTH;\n"
"      int ny = (y + dy + HEIGHT) % HEIGHT;\n"
"      count += grid[ny * WIDTH + nx];\n"
"    }\n"
"  }\n"
"  uchar alive = grid[id];\n"
"  next[id] = (alive && (count == 2 || count == 3)) || (!alive && count == 3);\n"
"}\n";

static void stop(int signalNumber)
{
    (void)signalNumber;
    running = 0;
}

static void check(cl_int status, const char *message)
{
    if (status != CL_SUCCESS) {
        fprintf(stderr, "%s failed with OpenCL error %d\n", message, status);
        exit(1);
    }
}

static cl_device_id chooseDevice(cl_platform_id platform)
{
    cl_device_id device = NULL;
    cl_int status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);

    if (status != CL_SUCCESS) {
        status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_CPU, 1, &device, NULL);
        check(status, "clGetDeviceIDs");
    }

    return device;
}

static void initializeGrid(unsigned char *grid)
{
    for (int i = 0; i < CELL_COUNT; i++) {
        grid[i] = ((double)rand() / RAND_MAX) < DENSITY;
    }
}

static void printGrid(const unsigned char *grid)
{
    printf("\033[H\033[2J");

    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            fputs(grid[y * WIDTH + x] ? "█" : " ", stdout);
        }
        putchar('\n');
    }

    fflush(stdout);
}

int main(void)
{
    signal(SIGINT, stop);
    srand((unsigned int)time(NULL));

    unsigned char grid[CELL_COUNT];
    initializeGrid(grid);

    cl_int status;
    cl_platform_id platform;
    status = clGetPlatformIDs(1, &platform, NULL);
    check(status, "clGetPlatformIDs");

    cl_device_id device = chooseDevice(platform);
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &status);
    check(status, "clCreateContext");

    cl_command_queue queue = clCreateCommandQueue(context, device, 0, &status);
    check(status, "clCreateCommandQueue");

    cl_program program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, &status);
    check(status, "clCreateProgramWithSource");

    status = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (status != CL_SUCCESS) {
        char log[4096];
        size_t logSize = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, sizeof(log), log, &logSize);
        fprintf(stderr, "clBuildProgram failed:\n%.*s\n", (int)logSize, log);
        return 1;
    }

    cl_kernel kernel = clCreateKernel(program, "next_generation", &status);
    check(status, "clCreateKernel");

    cl_mem current = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, CELL_COUNT, grid, &status);
    check(status, "clCreateBuffer current");
    cl_mem next = clCreateBuffer(context, CL_MEM_READ_WRITE, CELL_COUNT, NULL, &status);
    check(status, "clCreateBuffer next");

    const size_t globalSize = CELL_COUNT;

    while (running) {
        printGrid(grid);

        status = clSetKernelArg(kernel, 0, sizeof(cl_mem), &current);
        check(status, "clSetKernelArg current");
        status = clSetKernelArg(kernel, 1, sizeof(cl_mem), &next);
        check(status, "clSetKernelArg next");

        status = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL);
        check(status, "clEnqueueNDRangeKernel");
        status = clEnqueueReadBuffer(queue, next, CL_TRUE, 0, CELL_COUNT, grid, 0, NULL, NULL);
        check(status, "clEnqueueReadBuffer");

        cl_mem tmp = current;
        current = next;
        next = tmp;
        usleep(100000);
    }

    clReleaseMemObject(current);
    clReleaseMemObject(next);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    return 0;
}
