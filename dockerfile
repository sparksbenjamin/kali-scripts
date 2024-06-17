
# syntax=docker/dockerfile:1
FROM kalilinux/kali-rolling:latest
ENV VNC_PORT VNC_PORT
RUN apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y autoremove
RUN apt isntall -y install kali-linux-headless novnc x11vnc seclists
RUN x11vnc -display :0 -port ${VNC_PORT} -listen 0.0.0.0 -nopw -bg -xkb -ncache -ncache_cr -quiet -forever

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Entry point (optional, can be adjusted as needed)
CMD ["bash"]
