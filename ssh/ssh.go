package gossh

import (
	"bufio"
	"errors"
	"fmt"
	"golang.org/x/crypto/ssh"
	"io"
	"net"
	"os"
	"path/filepath"
	"time"
)

type Shell struct {
	Host         string
	Port         string
	User         string
	Password     string
	sshClient    *ssh.Client
	forwardLocal net.Listener

	reversingList []net.Listener
}

type ShellStatus struct {
	Err     error
	Output  string
	Command string
}

func (s *Shell) Connect(host, port, user, password string) (err error) {
	sshConfig := &ssh.ClientConfig{
		Timeout:         time.Second * 60,
		User:            user,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}
	sshConfig.Auth = []ssh.AuthMethod{ssh.Password(password)}
	sshAddr := fmt.Sprintf("%s:%s", host, port)
	s.sshClient, err = ssh.Dial("tcp", sshAddr, sshConfig)
	if err != nil {
		return err
	}
	return err
}

func (s *Shell) Connected() bool {
	return s.sshClient != nil && s.sshClient.Conn != nil
}

func (s *Shell) importProfile() string {
	return `PROFILE=~/.$(basename $SHELL)rc; 
			[ -f /etc/profile ] && . /etc/profile;
			[ -f $PROFILE ] && . $PROFILE; 
			[ -z $TMPDIR ] && export TMPDIR=$(dirname $(mktemp -d));
	`
}

func (s *Shell) Execute(command string) *ShellStatus {
	if s.sshClient == nil {
		return &ShellStatus{
			Err:     errors.New("ssh is not connected"),
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
	out, err := sess.CombinedOutput(s.importProfile() + command)
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

	// close started forward first
	var err error
	if s.forwardLocal != nil {
		_ = s.forwardLocal.Close()
	}

	// close other reverse listeners
	for _, listener := range s.reversingList {
		_ = listener.Close()
	}

	// listen local connection
	s.forwardLocal, err = net.Listen("tcp", localAddr)
	if err != nil {
		return err
	}

	// forward local port to remote port
	go func() {
		err = s.forward(s.forwardLocal, remoteAddr)
		if err != nil {
			fmt.Println(err)
		}
	}()

	return err
}

func (s Shell) forward(local net.Listener, remoteAddr string) error {
	if s.sshClient == nil {
		return errors.New("ssh is not connected")
	}

	for {
		client, err := local.Accept()
		if err != nil {
			fmt.Println("[Forward] Listen:", err)
			return err
		}
		fmt.Println("[Forward] Accept:", client.RemoteAddr())

		remote, err := s.sshClient.Dial("tcp", remoteAddr)
		fmt.Println("[Forward] Dail Remote:", remoteAddr)
		if err != nil {
			fmt.Println("[Forward] Dial Remote:", err)
			return err
		}

		go s.handleConnection(client, remote, "[Forward]")
	}
}

func (s *Shell) handleConnection(client, remote net.Conn, tag string) {
	defer func() {
		fmt.Println(tag, "Close:", client.LocalAddr(), "->", client.RemoteAddr(), ",",
			remote.LocalAddr(), "->", remote.RemoteAddr())
		_ = client.Close()
		_ = remote.Close()
	}()
	chDone := make(chan bool)

	go func() {
		_, err := io.Copy(client, remote)
		if err != nil {
			fmt.Println(tag, "Handle:", "[up]", err)
		}
		fmt.Println(tag, "Done:", "[up]", client.LocalAddr(), "->", client.RemoteAddr(), ",",
			remote.LocalAddr(), "->", remote.RemoteAddr())
		chDone <- true
	}()

	go func() {
		_, err := io.Copy(remote, client)
		if err != nil {
			fmt.Println(tag, "Handle:", "[down]", err)
			fmt.Println(tag, "Done:", "[down]", client.LocalAddr(), "->", client.RemoteAddr(), ",",
				remote.LocalAddr(), "->", remote.RemoteAddr())
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
	s.reversingList = append(s.reversingList, remote)
	for {
		conn, err := remote.Accept()
		if err != nil {
			fmt.Println("[Reverse] Accept:", err)
			return
		}
		fmt.Println("[Reverse] Accept:", conn.RemoteAddr())

		local, err := net.Dial("tcp", localAddr)
		if err != nil {
			fmt.Println("[Reverse] Local:", err)
			continue
		}

		go s.handleConnection(conn, local, "[Reverse]")
	}
}

func (s *Shell) UploadFile(src string, dst string) error {
	uploadFile, _ := os.Open(src)
	dstDir := filepath.Dir(dst)
	uploadCmd := fmt.Sprintf(`%s [ -d "%s" ] || mkdir -pv "%s"; cat > "%s"`,
		s.importProfile(), dstDir, dstDir, dst)

	sess, err := s.sshClient.NewSession()
	if err != nil {
		return err
	}
	sess.Stdin = bufio.NewReader(uploadFile)
	err = sess.Run(uploadCmd)

	return err
}

func (s *Shell) Close() error {
	for _, l := range s.reversingList {
		_ = l.Close()
	}

	err := s.sshClient.Close()
	s.sshClient = nil

	return err
}
