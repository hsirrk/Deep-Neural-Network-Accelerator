# Deep Neural Networks on FPGA

This project implements a deep neural network (DNN) accelerator on an FPGA for classifying handwritten digits from the MNIST dataset. The design uses an embedded Nios II processor and interfaces with off-chip SDRAM for memory storage. The network is a multi-layer perceptron (MLP) consisting of 784 input neurons, two hidden layers with 1000 neurons each, and 10 output neurons corresponding to the digits 0-9. The ReLU activation function is used to process the layers.

The neural network operates on signed Q16.16 fixed-point numbers for efficient FPGA implementation. The system is optimized for performance with a focus on memory access, fixed-point arithmetic, and system-on-chip integration. The FPGA design also includes a Phase-Locked Loop (PLL) for clock generation and a custom SDRAM controller for efficient data handling.

## Key Features

- **Deep Neural Network (DNN)**: Multi-layer perceptron (MLP) to classify handwritten digits from the MNIST dataset.
- **Fixed-Point Arithmetic**: Uses Q16.16 fixed-point format for efficient computation on FPGA.
- **Nios II Processor**: Embedded softcore CPU for running the inference code.
- **SDRAM Interface**: Off-chip memory for storing weights and activations.
- **Optimized Design**: Custom accelerators for dot products and memory copying to speed up computation.
- **VGA Output**: Integrated VGA core for visualizing the classification results on a display.

## Technologies Used

- **FPGA**: Intel FPGA, Nios II processor
- **Memory**: SDRAM
- **Fixed-Point Arithmetic**: Q16.16 signed fixed-point representation
- **VGA**: For output visualization

## Project Structure

- **src/**: Contains Verilog code for the neural network components, including dot product accelerators, memory copy accelerators, and the overall system integration.
- **data/**: Preformatted MNIST dataset and weights for the neural network.
- **docs/**: Additional documentation on the design and implementation of the project.
- **scripts/**: Python scripts for data preprocessing and training the neural network.
  
## How to Run

1. Install Intel FPGA tools, including the Nios II processor and Platform Designer tool.
2. Set up the project in Quartus, including the Nios II system and custom components.
3. Compile the design and load it onto the FPGA (DE1-SoC recommended).
4. Use the integrated VGA display to visualize the classification results.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to Intel for providing the FPGA tools and resources to build this accelerator.
- The MNIST dataset is publicly available and used here for educational purposes.
