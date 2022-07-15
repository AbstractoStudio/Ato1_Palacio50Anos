# Kinect Windows 10 Install Instructions
- Install [Kinect for Windows SDK 2.0](https://www.microsoft.com/en-us/download/details.aspx?id=44561)
- If Kinect is not being recognized, try starting manually the Kinect Monitor service ([source](https://social.msdn.microsoft.com/Forums/en-US/07e1408b-ce52-4763-ab72-9a87ddbec697/required-kinect-software-not-detected-error?forum=kinectv2sd))

## Windows Dependencies
- Visual Studio 2015+
- Microsoft SDK

## Requirements for multiple Kinects

- Install [libfreenect2](https://github.com/OpenKinect/libfreenect2) using [vcpkg](https://github.com/Microsoft/vcpkg#quick-start-windows):
	```
	git clone https://github.com/Microsoft/vcpkg.git
	cd vcpkg
	bootstrap-vcpkg.bat
	./vcpkg integrate install
	vcpkg install libfreenect2
	```
	- Use Zadig to use libusbK driver (details on the libfreenect2 repository)

  - [More information on USB 3.0 support](http://docs.ipisoft.com/Multiple_Kinects_v2_on_a_Single_PC).

- Install **Open Kinect for Processing** Library
