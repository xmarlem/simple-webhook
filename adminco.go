package main

import (
  "encoding/json"
  "fmt"
  "io"
  "log"
  "net/http"

  admissionv1 "k8s.io/api/admission/v1"
  v1 "k8s.io/api/core/v1"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type Adminco struct {
}

func (ac *Adminco) serve(w http.ResponseWriter, r *http.Request) {
  var body []byte
  if r.Body != nil {
    if data, err := io.ReadAll(r.Body); err == nil {
      body = data
    }
  }
  if len(body) == 0 {
    log.Fatal("empty body")
    http.Error(w, "empty body", http.StatusBadRequest)
    return
  }
  log.Print("Received request")

  if r.URL.Path != "/validate" {
    log.Fatal("no validate")
    http.Error(w, "no validate", http.StatusBadRequest)
    return
  }

  arRequest := admissionv1.AdmissionReview{}
  if err := json.Unmarshal(body, &arRequest); err != nil {
    log.Fatal("incorrect body")
    http.Error(w, "incorrect body", http.StatusBadRequest)
  }

  raw := arRequest.Request.Object.Raw
  pod := v1.Pod{}
  if err := json.Unmarshal(raw, &pod); err != nil {
    log.Fatal("error deserializing pod")
    return
  }

  allowed := false
  msg := "Keep calm and not add more crap in the cluster!"

  if pod.Name == "smooth-app" {
    allowed = true
    msg = ""
  }

  arResponse := admissionv1.AdmissionReview{
    Response: &admissionv1.AdmissionResponse{
      UID:     arRequest.Request.UID,
      Allowed: allowed,
      Result: &metav1.Status{
        Message: msg,
      },
    },
    TypeMeta: arRequest.TypeMeta,
    Request:  arRequest.Request,
  }

  resp, err := json.Marshal(arResponse)
  if err != nil {
    log.Fatalf("Can't encode response: %v", err)
    http.Error(w, fmt.Sprintf("could not encode response: %v", err), http.StatusInternalServerError)
  }
  log.Printf("Ready to write reponse ...%v", string(resp))
  if _, err := w.Write(resp); err != nil {
    log.Fatalf("Can't write response: %v", err)
    http.Error(w, fmt.Sprintf("could not write response: %v", err), http.StatusInternalServerError)
  }
}
