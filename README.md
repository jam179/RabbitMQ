# RabbitMQ
Module to install RabbitMQ and it prerequisite Erlang

- Test to see if Rabbit is installed.
	- Test If installed, stop 
	- Else continue install.
- Create Erlang download directory.
	- Test If Erlang download directory exist, continue.
	- Else create directory.
- Create RabbitMQ download directory.
	- Test If RabbbitMQ download directory exist, continue.
	- Else create directory.
- Download Erlang and place in Erlang directory
	- Test If Erlang installer is present, continue.
	- Else Download installer.
- Download RabbitMQ and place in RabbitMQ directory
	- Test If RabbbitMQ installer is present, continue.
	- Else Download installer.
- Install Erlang.
	- Test If Erlang is installed, continue.
	- Else Install Erlang.
- Install RabbitMQ.
	- Test If RabbitMQ is installed, continue.
	- Else Install RabbitMQ.
- Enable RabbbitMQ Management Plug-in
	- Test If RabbitMQ management is installed(listening on port 15647), continue.
	- Else Install RabbitMQ.
