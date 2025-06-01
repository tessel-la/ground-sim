# Start with Ubuntu 22.04 (Jammy) base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DISTRO=humble

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# Setup retry function for apt
RUN echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

# Update apt sources to use a different mirror
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://us.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu/|http://us.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

# Install dependencies and set up ROS 2 repository
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    && add-apt-repository universe \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Install ROS 2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-base \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    ros-humble-joint-state-publisher-gui \
    ros-humble-xacro \
    ros-humble-rviz2 \
    # Additional tools
    bash-completion \
    build-essential \
    cmake \
    curl \
    gdb \
    git \
    nano \
    openssh-client \
    sudo \
    vim \
    tmux \
    ruby \
    ruby-dev \
    # Add TurtleBot3 Gazebo and its dependencies
    ros-humble-turtlebot3 \
    ros-humble-turtlebot3-simulations \
    ros-humble-gazebo-ros-pkgs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install tmuxinator gem
RUN gem install tmuxinator

# Create a non-root user 'rosuser'
ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=rosuser
ENV USERNAME=$USERNAME
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # Source ROS setup in .bashrc for interactive shells
    echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/$USERNAME/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/$USERNAME/.bashrc

# Switch to the non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Create tmuxinator config directory as rosuser
RUN mkdir -p /home/$USERNAME/.config/tmuxinator


WORKDIR /home/$USERNAME/agv_ws
RUN mkdir src
# Initialize rosdep and install dependencies
RUN sudo apt-get update && \
    sudo rosdep init || echo "Rosdep already initialized" && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y --as-root apt:true && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    rm -rf /home/$USERNAME/.ros

# Install colcon mixin
RUN sudo apt-get update && \
    sudo apt-get install -y python3-colcon-common-extensions python3-colcon-mixin && \
    colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update default && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Build the workspace
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --symlink-install --mixin release

# Add sourcing of the new workspace to .bashrc
RUN echo "source ~/agv_ws/install/setup.bash" >> /home/$USERNAME/.bashrc

# Copy the CORS-enabled mesh server script
COPY cors_mesh_server.py /home/$USERNAME/cors_mesh_server.py
RUN sudo chown $USERNAME:$USERNAME /home/$USERNAME/cors_mesh_server.py && \
    chmod +x /home/$USERNAME/cors_mesh_server.py

# Set up the entrypoint script
RUN echo '#!/bin/bash' > /home/$USERNAME/ros_entrypoint.sh && \
    echo 'set -e' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '# Source ROS 2 environment' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo 'source /opt/ros/$ROS_DISTRO/setup.bash' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '# Source the workspace setup' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo 'if [ -f /home/$USERNAME/agv_ws/install/setup.bash ]; then' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '  source /home/$USERNAME/agv_ws/install/setup.bash' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo 'fi' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo '# Execute the command passed to the container' >> /home/$USERNAME/ros_entrypoint.sh && \
    echo 'exec "$@"' >> /home/$USERNAME/ros_entrypoint.sh

# Make the entrypoint script executable and set it as the entrypoint
RUN sudo chmod +x /home/$USERNAME/ros_entrypoint.sh
ENTRYPOINT ["/home/rosuser/ros_entrypoint.sh"]

# Expose port for HTTP mesh server
EXPOSE 8000

# Default command to start a bash shell
CMD ["bash"] 