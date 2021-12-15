# Installation Instructions for Love2D  

Go to installer URL: https://love2d.org  

## **Windows**  
 - Install the "64-bit installer"
 - Run through the installation wizard
 
 **Add Love2D to Path**
 - Open Control Panel  
 - System  
 - Advanced System Settings  
 - Environment Variables  
 - In the section "System Variables", find the PATH environment variable and select it  
 - Edit  
 - New System Variable  
 - "C:\Program Files\LOVE\"  
 - Click OK  

 Be sure to restart a command prompt terminal.  

 Open a command prompt and type `love`  

## **Debian/Ubuntu**  
 - Find Love2D on debian package manager  
 - Debian 11: https://debian.pkgs.org/10/debian-main-arm64/love_11.1-2_arm64.deb.html  
 - Download file  
 - `sudo apt update && apt upgrade`  
 - `sudo chmod +x fileName`  
 - `sudo dpkg -i fileName`  
 - `sudo apt update && apt upgrade`  

Type `love` in a terminal to test.  