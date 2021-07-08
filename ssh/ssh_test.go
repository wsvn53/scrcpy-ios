package gossh

import (
	"fmt"
	"testing"
	"time"
)

func TestShell_Execute(t *testing.T) {
	shell := &Shell{ }
	fmt.Println(shell.Connect("wsen.me", "2022", "root", "root"))
	fmt.Println(shell.Execute(`
		nohup sleep 1000 &
	`))
}

func TestShell_Forward(t *testing.T) {
	shell := &Shell{}
	fmt.Println(shell.Connect("wsen.me", "2022", "root", "root"))
	fmt.Println(shell.Forward("localhost:1234", "localhost:1234"))
	time.Sleep(time.Second * 60)
}

func TestShell_Reverse(t *testing.T) {
	shell := &Shell{}
	fmt.Println(shell.Connect("wsen.me", "2022", "root", "root"))
	fmt.Println(shell.Reverse("localhost:1234", "localhost:1234"))
	time.Sleep(time.Second * 60)
}