#!/usr/bin/env bats

@test "firewalld is enabled" {
        run systemctl is-enabled firewalld.service
        [ "$status" -eq 0 ]
}

@test "firewalld is active" {
        # Ubuntu uses upstart to start firewalld...
        # run systemctl is-active firewalld.service
        run service firewalld status
        [ "$status" -eq 0 ]
}

@test "default zone is public" {
        run firewall-cmd --get-default-zone
        [ "$output" = "public" ]
}

@test "mergezone has service http" {
        run firewall-cmd --zone=mergezone --query-service=http
        [ "$status" -eq 0 ]
}

@test "mergezone has service https" {
        run firewall-cmd --zone=mergezone --query-service=https
        [ "$status" -eq 0 ]
}

@test "mergezone has service ssh" {
        run firewall-cmd --zone=mergezone --query-service=ssh
        [ "$status" -eq 0 ]
}

@test "mergezone has service nrpe" {
        run firewall-cmd --zone=mergezone --query-service=nrpe
        [ "$status" -eq 0 ]
}

@test "prunezone has service http" {
        run firewall-cmd --zone=prunezone --query-service=http
        [ "$status" -eq 0 ]
}

@test "prunezone has service https" {
        run firewall-cmd --zone=prunezone --query-service=https
        [ "$status" -eq 0 ]
}

@test "prunezone does not have service ssh" {
        run firewall-cmd --zone=prunezone --query-service=ssh
        [ "$status" -ne 0 ]
}

@test "filterzone has service http" {
        run firewall-cmd --zone=filterzone --query-service=http
        [ "$status" -eq 0 ]
}

@test "filterzone has service https" {
        run firewall-cmd --zone=filterzone --query-service=https
        [ "$status" -eq 0 ]
}

@test "filterzone does not have service ssh" {
        run firewall-cmd --zone=filterzone --query-service=ssh
        [ "$status" -ne 0 ]
}

@test "mergezone has port 8080/tcp" {
        run firewall-cmd --zone=mergezone --query-port=8080/tcp
        [ "$status" -eq 0 ]
}

@test "mergezone has port 8443/tcp" {
        run firewall-cmd --zone=mergezone --query-port=8443/tcp
        [ "$status" -eq 0 ]
}

@test "mergezone has port 10443/tcp" {
        run firewall-cmd --zone=mergezone --query-port=10443/tcp
        [ "$status" -eq 0 ]
}

@test "prunezone does not have port 8080/tcp" {
        run firewall-cmd --zone=prunezone --query-port=8080/tcp
        [ "$status" -ne 0 ]
}

@test "prunezone has port 8443/tcp" {
        run firewall-cmd --zone=prunezone --query-port=8443/tcp
        [ "$status" -eq 0 ]
}

@test "filterzone does not have port 8080/tcp" {
        run firewall-cmd --zone=filterzone --query-port=8080/tcp
        [ "$status" -ne 0 ]
}

@test "filterzone has port 8443/tcp" {
        run firewall-cmd --zone=filterzone --query-port=8443/tcp
        [ "$status" -eq 0 ]
}

@test "mergezone has source 10.93.0.0/24" {
        run firewall-cmd --zone=mergezone --query-source=10.93.0.0/24
        [ "$status" -eq 0 ]
}

@test "mergezone has source 10.93.1.0/24" {
        run firewall-cmd --zone=mergezone --query-source=10.93.1.0/24
        [ "$status" -eq 0 ]
}

@test "prunezone has source 10.94.0.0/24" {
        run firewall-cmd --zone=prunezone --query-source=10.94.0.0/24
        [ "$status" -eq 0 ]
}

@test "prunezone does not have source 10.94.1.0/24" {
        run firewall-cmd --zone=prunezone --query-source=10.94.1.0/24
        [ "$status" -ne 0 ]
}

@test "filterzone has source 10.95.0.0/24" {
        run firewall-cmd --zone=filterzone --query-source=10.95.0.0/24
        [ "$status" -eq 0 ]
}

@test "filterzone does not have source 10.95.1.0/24" {
        run firewall-cmd --zone=filterzone --query-source=10.95.1.0/24
        [ "$status" -ne 0 ]
}

@test "filterzone does not have source 10.95.1.0/24" {
        run firewall-cmd --zone=filterzone --query-source=10.95.1.0/24
        [ "$status" -ne 0 ]
}

@test "mergezone has rule family=ipv4 source address=10.93.0.1 accept" {
        run firewall-cmd --zone=mergezone --query-rich-rule="rule family=ipv4 source address=10.93.0.1 accept"
        [ "$status" -eq 0 ]
}

@test "mergezone has rule family=ipv4 source address=10.93.0.2 accept" {
        run firewall-cmd --zone=mergezone --query-rich-rule="rule family=ipv4 source address=10.93.0.2 accept"
        [ "$status" -eq 0 ]
}

@test "mergezone has rule family=ipv4 source address=10.93.0.3 accept" {
        run firewall-cmd --zone=mergezone --query-rich-rule="rule family=ipv4 source address=10.93.0.3 accept"
        [ "$status" -eq 0 ]
}

@test "prunezone has rule family=ipv4 source address=10.94.0.1 accept" {
        run firewall-cmd --zone=prunezone --query-rich-rule="rule family=ipv4 source address=10.94.0.1 accept"
        [ "$status" -eq 0 ]
}

@test "prunezone does not have rule family=ipv4 source address=10.94.0.2 accept" {
        run firewall-cmd --zone=prunezone --query-rich-rule="rule family=ipv4 source address=10.94.0.2 accept"
        [ "$status" -ne 0 ]
}

@test "filterzone has rule family=ipv4 source address=10.95.0.1 accept" {
        run firewall-cmd --zone=filterzone --query-rich-rule="rule family=ipv4 source address=10.95.0.1 accept"
        [ "$status" -eq 0 ]
}

@test "filterzone does not have rule family=ipv4 source address=10.95.0.2 accept" {
        run firewall-cmd --zone=filterzone --query-rich-rule="rule family=ipv4 source address=10.95.0.2 accept"
        [ "$status" -ne 0 ]
}
