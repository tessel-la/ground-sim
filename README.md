# Ground Sim

AGV - Autonomous Ground Vehicles Planning, Execution and Visualization environment.

This repository provides an AGV simulation environment specifically configured and tested for the [Robo-Boy](https://github.com/tessel-la/robo-boy) project. It utilizes components and setup based on the Turtlebot3 packages and Gazebo for simulation.

## Overview

This simulation environment is designed to facilitate the development and testing of autonomous navigation and interaction tasks for AGVs, with a primary focus on TurtleBot3.

## Features

- ROS 2 Humble
- TurtleBot3
- Gazebo for realistic simulation
- `tmuxinator` for easy launch of simulation components
- Dockerized for consistent and reproducible environments

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- An X11 server (for GUI applications like Gazebo and RViz)

### Build and Run

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd ground-sim
    ```

2.  **Build the Docker image and run the container:**
    ```bash
    docker-compose up --build -d
    ```

3.  **Access the container:**
    ```bash
    docker exec -it agv_sim_cont bash
    ```

4.  **Launch the simulation using tmuxinator:**
    Inside the container, run:
    ```bash
    tmuxinator start agv_simulation_setup
    ```

This will launch the TurtleBot3 Gazebo simulation and any other configured components.

## Workspace Structure (inside the container)

- `/home/rosuser/agv_ws`: The main ROS 2 workspace.
  - `src/`: This directory is intended for your custom ROS 2 packages. If you have local packages, you can add them by:
    - Modifying the `Dockerfile` to `COPY` them into the image.
    - Mounting them as a volume in `docker-compose.yml`.

## Customization

-   **Simulation launch**: Modify `simulation/turtlebot3_gazebo_setup.yml` to change the `tmuxinator` launch configuration.
    - The `TURTLEBOT3_MODEL` environment variable is set to `burger` by default in this file. You can change it to other models like `waffle` or `waffle_pi` if needed.
-   **Dockerfile**: Add or remove ROS packages or other dependencies in `Dockerfile`.
-   **Gazebo worlds and models**: Add or modify Gazebo worlds and TurtleBot3 models as needed within your ROS packages.

