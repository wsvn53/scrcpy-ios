package gossh

import (
	"bufio"
	"errors"
	"fmt"
	"golang.org/x/crypto/ssh"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"time"
)

type Shell struct {
	Host 		string
	Port 		string
	User 		string
	Password 	string
	sshClient 	*ssh.Client
}

type ShellStatus struct {
	Err 	error
	Output  string
	Command string
}

func (s *Shell) Connect(host, port, user, password string) (err error) {
	sshConfig := &ssh.ClientConfig{
		Timeout: 		time.Second * 60,
		User: 			user,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}
	sshConfig.Auth = []ssh.AuthMethod{ ssh.Password(password) }
	sshAddr := fmt.Sprintf("%s:%s", host, port)
	s.sshClient, err = ssh.Dial("tcp", sshAddr, sshConfig)
	if err != nil {
		return err
	}
	return err
}

func (s *Shell) Connected() bool {
	return s.sshClient != nil
}

func (s *Shell) Execute(command string) *ShellStatus {
	if s.sshClient == nil {
		return &ShellStatus {
			Err: errors.New("ssh is not connected"),
			Command: command,
		}
	}

	sess, err := s.sshClient.NewSession()
	if err != nil {
		return &ShellStatus{
			Err:     err,
			Command: command,
		}
	}
	out, err := sess.CombinedOutput("PATH=$PATH:/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin " + command)
	return &ShellStatus{
		Err:     err,
		Output:  string(out),
		Command: command,
	}
}

func (s *Shell) Forward(localAddr, remoteAddr string) error {
	if s.sshClient == nil {
		return errors.New("ssh is not connected")
	}

	// listen local connection
	local, err := net.Listen("tcp", localAddr)
	if err != nil {
		return err
	}

	// listen remote connection
	remote, err := s.sshClient.Dial("tcp", remoteAddr)
	if err != nil {
		return err
	}

	// forward local port to remote port
	go func() {
		err = s.forward(local, remote)
		if err != nil {
			fmt.Println(err)
		}
	}()

	return err
}

func (s Shell) forward(local net.Listener, remote net.Conn) error {
	if s.sshClient == nil {
		return errors.New("ssh is not connected")
	}

	for {
		client, err := local.Accept()
		if err != nil {
			fmt.Println("Listen:", err)
			return err
		}
		go s.handleConnection(client, remote)
	}
}

func (s *Shell) handleConnection(client, remote net.Conn) {
	defer client.Close()
	chDone := make(chan bool)

	go func() {
		_, err := io.Copy(client, remote)
		if err != nil {
			log.Println("Handle:", err)
		}
		chDone <- true
	}()

	go func() {
		_, err := io.Copy(remote, client)
		if err != nil {
			log.Println("Handle:", err)
		}
		chDone <- true
	}()

	<-chDone
}

func (s *Shell) Reverse(remoteAddr, localAddr string) error {
	if s.sshClient == nil {
		return errors.New("ssh is not connected")
	}

	listen, err := s.sshClient.Listen("tcp", remoteAddr)
	if err != nil {
		return err
	}

	// reverse remote listener to local addr
	go s.reverse(listen, localAddr)

	return err
}

func (s *Shell) reverse(remote net.Listener, localAddr string) {
	for {
		conn, err := remote.Accept()
		if err != nil {
			fmt.Println("Accept:", err)
			return
		}

		local, err := net.Dial("tcp", localAddr)
		if err != nil {
			fmt.Println("Local:", err)
			continue
		}

		go s.handleConnection(conn, local)
	}
}

func (s *Shell) UploadFile(src string, dst string) error {
	uploadFile, _ := os.Open(src)
	dstDir := filepath.Dir(dst)
	uploadCmd := fmt.Sprintf(`[ -d "%s" ] || mkdir -pv "%s"; cat > "%s"`,
		dstDir, dstDir, dst)

	sess, err := s.sshClient.NewSession()
	if err != nil { return err }
	sess.Stdin = bufio.NewReader(uploadFile)
	err = sess.Run(uploadCmd)

	return err
}

func (s *Shell) Close() error {
	err := s.sshClient.Close()
	s.sshClient = nil
	return err
}