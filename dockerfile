
# syntax=docker/dockerfile:1
FROM kalilinux/kali-rolling:latest
ENV VNC_PORT VNC_PORT
RUN apt update
RUN apt -y upgrade 
RUN apt -y dist-upgrade 
RUN apt -y autoremove
RUN apt -y install kali-linux-headless
RUN apt -y install seclists
RUN apt -y install kali-desktop-xfce
RUN apt -y install x11vnc
RUN curl -fsSL https://raw.githubusercontent.com/sparksbenjamin/kali-scripts/master/install.sh | sh
#RUN x11vnc -display :0 -port ${VNC_PORT} -listen 0.0.0.0 -nopw -bg -xkb -ncache -ncache_cr -quiet -forever

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Entry point (optional, can be adjusted as needed)
CMD ["bash"]
