package main

import (
  "context"
  "crypto/tls"
  "flag"
  "fmt"
  "log"
  "net/http"
  "os"
  "os/signal"
  "syscall"
)

const (
  port = "443"
)

var (
  tlscert, tlskey string
)

func main() {
  flag.StringVar(&tlscert, "tlsCertFile", "/etc/certs/cert.pem", "File containing the x509 Certificate for HTTPS.")
  flag.StringVar(&tlskey, "tlsKeyFile", "/etc/certs/key.pem", "File containing the x509 private key to --tlsCertFile.")

  flag.Parse()

  certs, err := tls.LoadX509KeyPair(tlscert, tlskey)
  if err != nil {
    log.Fatalf("Filed to load key pair: %v", err)
  }

  server := &http.Server{
    Addr:      fmt.Sprintf(":%v", port),
    TLSConfig: &tls.Config{Certificates: []tls.Certificate{certs}},
  }

  ac := Adminco{}

  mux := http.NewServeMux()
  mux.HandleFunc("/validate", ac.serve)
  server.Handler = mux

  log.Printf("Server running listening in port: %s", port)
  // start webhook server in new rountine
  go func() {
    if err := server.ListenAndServeTLS("", ""); err != nil {
      log.Fatalf("Failed to listen and serve webhook server: %v", err)
    }
  }()

  // listening shutdown singal
  signalChan := make(chan os.Signal, 1)
  signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)
  fmt.Println("waiting for SIGINT/SIGTERM")
  <-signalChan

  log.Print("Got shutdown signal, shutting down webhook server gracefully...")
  server.Shutdown(context.Background())
}
