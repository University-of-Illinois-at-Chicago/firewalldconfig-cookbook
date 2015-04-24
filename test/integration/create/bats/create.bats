#!/usr/bin/env bats

@test "firewalld is enabled" {
        run systemctl is-enabled firewalld.service
        [ "$status" -eq 0 ]
}

@test "firewalld is active" {
        run service firewalld status
        #run systemctl is-active firewalld.service
        [ "$status" -eq 0 ]
}

@test "default zone is public" {
        run firewall-cmd --get-default-zone
        [ "$output" = "public" ]
}

@test "public zone has service http" {
        run firewall-cmd --zone=public --query-service=http
        [ "$status" -eq 0 ]
}

@test "public zone has service https" {
        run firewall-cmd --zone=public --query-service=https
        [ "$status" -eq 0 ]
}

@test "public zone has service ssh" {
        run firewall-cmd --zone=public --query-service=ssh
        [ "$status" -eq 0 ]
}

@test "public zone has port 8080/tcp" {
        run firewall-cmd --zone=public --query-port=8080/tcp
        [ "$status" -eq 0 ]
}

@test "public zone has port 8443/tcp" {
        run firewall-cmd --zone=public --query-port=8443/tcp
        [ "$status" -eq 0 ]
}

@test "public zone has port 7/udp" {
        run firewall-cmd --zone=public --query-port=7/udp
        [ "$status" -eq 0 ]
}

@test "campus zone has service http" {
        run firewall-cmd --zone=campus --query-service=http
        [ "$status" -eq 0 ]
}

@test "campus zone has service https" {
        run firewall-cmd --zone=campus --query-service=https
        [ "$status" -eq 0 ]
}

@test "campus zone has service nrpe" {
        run firewall-cmd --zone=campus --query-service=nrpe
        [ "$status" -eq 0 ]
}

@test "campus zone has service ssh" {
        run firewall-cmd --zone=campus --query-service=ssh
        [ "$status" -eq 0 ]
}

@test "campus zone has source 128.248.0.0/16" {
        run firewall-cmd --zone=campus --query-source=128.248.0.0/16
        [ "$status" -eq 0 ]
}

@test "campus zone has source 131.193.0.0/16" {
        run firewall-cmd --zone=campus --query-source=131.193.0.0/16
        [ "$status" -eq 0 ]
}
