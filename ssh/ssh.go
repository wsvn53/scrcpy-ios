package gossh

import (
	"fmt"
	"golang.org/x/crypto/ssh"
	"io"
	"log"
	"net"
	"time"
)

type Shell struct {
	Host 		string
	Port 		string
	User 		string
	Password 	string
	sshClient 	*ssh.Client
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

func (s *Shell) Execute(command string) (output string, err error) {
	sess, err := s.sshClient.NewSession()
	if err != nil {
		return  "", err
	}
	out, err := sess.CombinedOutput(command)
	return  string(out), err
}

func (s *Shell) Forward(localAddr, remoteAddr string) error {
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
	go s.forward(local, remote)

	return err
}

func (s Shell) forward(local net.Listener, remote net.Conn) {
	for {
		client, err := local.Accept()
		if err != nil {
			fmt.Println("Listen:", err)
			return
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