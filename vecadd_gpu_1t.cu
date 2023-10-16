#include <iostream>
#include <math.h>
#include <chrono>

// now this is a CUDA kernel function that is a device code which runs on the GPU
__global__
void add(int n, float *x, float *y)
{
    for (int i = 0; i < n; i++)
    {
        y[i] = x[i] + y[i];
    }
}

int main(void)
{
    int N = 1 << 28; // 256M elements

    
    /*
    float *x = new float[N];
    float *y = new float[N];
    */

    // allocate unified memory that's reachable from both the CPU and the GPU
    float *x, *y;
    cudaMallocManaged(&x, N * sizeof(float));
    cudaMallocManaged(&y, N * sizeof(float));

    // initialize x and y arrays on the host
    for (int i = 0; i < N; i++)
    {
        x[i] = 1.0f;
        y[i] = 2.0f;
    }

    // start timer
    std::chrono::time_point<std::chrono::high_resolution_clock> start_time = std::chrono::high_resolution_clock::now();

    // Run kernel on 1M elements on the CPU
    // add(N, x, y);

    // Run kernel on elements on the GPU
    add<<<1, 1>>>(N, x, y);

    // end timer
    std::chrono::time_point<std::chrono::high_resolution_clock> end_time = std::chrono::high_resolution_clock::now();

    // we have to wait for the GPU to finish before accessing on host
    cudaDeviceSynchronize();

    // Check for errors (all values should be 3.0f)
    float maxError = 0.0f;
    for (int i = 0; i < N; i++)
        maxError = fmax(maxError, fabs(y[i] - 3.0f));
    std::cout << "Max error: " << maxError << std::endl;

    // output runtime
    std::chrono::duration<double> elapsed = end_time - start_time;
    std::cout << "Elapsed time: " << elapsed.count() << " s\n";

    // Free memory
    // delete[] x;
    // delete[] y;
    cudaFree(x);
    cudaFree(y); // we "malloc'd" them with CUDA so it's now cudaFree

    return 0;
}
