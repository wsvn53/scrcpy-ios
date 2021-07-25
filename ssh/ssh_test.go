package gossh

import (
	"fmt"
	"testing"
	"time"
)

func TestShell_Execute(t *testing.T) {
	shell := &Shell{ }
	fmt.Println(shell.Connect("wsen.me", "2022", "root", "root"))
	fmt.Println(shell.Execute(`pgrep -f "scrcpy[-]server" && kill $(pgrep -f "scrcpy[-]server")`))
	fmt.Println(shell.Execute(`export; which cat`))
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

func TestShell_UploadFile(t *testing.T) {
	shell := &Shell{}
	fmt.Println(shell.Connect("wsen.me", "2022", "root", "root"))
	fmt.Println(shell.UploadFile("/usr/local/share/scrcpy/scrcpy-server", "/usr/local/share/scrcpy/scrcpy-server"))
}