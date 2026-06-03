package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Deployment"
    not input.request.object.spec.template.spec.securityContext.runAsNonRoot == true
    msg := "DEFENSE PROJECT SECURITY ALERT: Django containers must not run as root user!"
}