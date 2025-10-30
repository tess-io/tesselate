mock_provider "proxmox" { }

variables {
  node = "test-node"
  
  groups = {
    control = {
      size       = 2
      node_name  = "control-node"
      is_control = true

      resources = {
        cpu    = 4
        memory = 4 
      }
    }

    worker = {
      size       = 2
      node_name  = "worker-node"

      resources = {
        cpu    = 4
        memory = 4
      }
    }
  }

  start_id = 100

  auth = {
    user = "test-user"
    pass = "$5$FLs86nDTeGMWRQJj$2L9rGoH2CEMvZfLSvoLa08UMGd8Lw09KXdgXXqEcyOC"

    ssh_keys = null
  }

  cert = {
    ca = <<-EOF
      -----BEGIN CERTIFICATE-----
      MIIDPTCCAiWgAwIBAgIUK91HEwhoUgKwNn+wiCxCP5yPEBMwDQYJKoZIhvcNAQEL
      BQAwLjELMAkGA1UEBhMCUlUxDTALBgNVBAoMBFRlc3MxEDAOBgNVBAMMB3Rlc3Mu
      aW8wHhcNMjUxMDE3MjMwNDI1WhcNMzUxMDE3MjMwNDI1WjAuMQswCQYDVQQGEwJS
      VTENMAsGA1UECgwEVGVzczEQMA4GA1UEAwwHdGVzcy5pbzCCASIwDQYJKoZIhvcN
      AQEBBQADggEPADCCAQoCggEBAK77SXJM9MyvYaRcyvc3H+dnP+NqBtvFXatxAP5a
      XZq9z5UKttgnyOI7BZBqKbbTqTiJhsJUEjjPHC7RKRvfTW4DUHmnq7HWhRV9xFQz
      8AmlgWKTV7lY0e5jkMenEmLsRJ2qbN6yUS9oyQUwylrSpYSZF93tZ3pcRuOT8rES
      V7hSvUumxhMcWTIhMRxjEdXvqzY1iueG3VQadHqTosxxRakMRe4ynqs9jIdO530N
      qZCsYgVdW9aydWYL6JY7qH2CdCfu5WuRGOvDXKOYOY6DV6ZlmTpkrMUSl9imFnDf
      u6IwL6lHtt7Rur/GpySk0B/iqXbHZAGrq3seBzXXCtZaSBsCAwEAAaNTMFEwHQYD
      VR0OBBYEFBH3iuIzwG5wjKaTTWmCQWiuY1oVMB8GA1UdIwQYMBaAFBH3iuIzwG5w
      jKaTTWmCQWiuY1oVMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
      AGVSkkwyHYCZM2qKSy+jSgGyMpw9MnkmQmhsU1h/LfRkln5gCJlP2ihVap+ZhppX
      Dw6iRrKkPs1+kFO119qqgia9ID2y8+ZBoU7b3Uw4sx4JodHp9VeA/U8AiT850kHW
      0ZRfWefxucrOdyERLCwi0IT3dvnvWRr4duUanI8p1VDwpwCSiOXqiOR5GZdAtz8s
      tfVAHP8HPyEtQ9JvYRktgDwyHu1uDcZXZxsQ/M7eAudrzlKwT+x2IQ48bQk9Xqy7
      L0bnCry6axb0w8Ikq4LwddJziCpNtRfSBuSzNGIPIVw9BxiE5lWwNRYsMpe5vvw+
      eVg5fz9JaTod6Dafs9VJc48=
      -----END CERTIFICATE-----
    EOF
    key = <<-EOF
      -----BEGIN PRIVATE KEY-----
      MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCu+0lyTPTMr2Gk
      XMr3Nx/nZz/jagbbxV2rcQD+Wl2avc+VCrbYJ8jiOwWQaim206k4iYbCVBI4zxwu
      0Skb301uA1B5p6ux1oUVfcRUM/AJpYFik1e5WNHuY5DHpxJi7ESdqmzeslEvaMkF
      MMpa0qWEmRfd7Wd6XEbjk/KxEle4Ur1LpsYTHFkyITEcYxHV76s2NYrnht1UGnR6
      k6LMcUWpDEXuMp6rPYyHTud9DamQrGIFXVvWsnVmC+iWO6h9gnQn7uVrkRjrw1yj
      mDmOg1emZZk6ZKzFEpfYphZw37uiMC+pR7be0bq/xqckpNAf4ql2x2QBq6t7Hgc1
      1wrWWkgbAgMBAAECggEACtWwdI1jUxFBAIZmYuxc4103TYORLSaJaEY1A4rg5OX/
      5oClVbkQ7UEuVQTd1F5Cyidp2rqN7kqUuillXD51cuxtnTrOnNJlpzEEaRpWMKK4
      4juxYN6pERPFMTedIdbzYLfeyeNMt5zLZbDhtsH4Ub+RBMLgd2kjUpAkpOY33EfZ
      DYkQiwfZJUqasKPJ6M1VN4yPCZX5jrU/2zIjEe2ZeiEB4xm0fDkyv5KaNsmKpVn3
      83YNixRJ33LXOkjF8mv28egYLm7UNPpLZKMh7oGrBtkRllhVIDL4iXsqJrV+oMVX
      aUPrXJaOE76NJcNfE3FEYxRG3hd9loUndsEZwYAu8QKBgQDX4IEtrJOS+D4hbSjj
      oXwFgfT0Yd9ryfAa1yWYGNvj5fKKad6ePR/FvzRjhNsKFcj+1KTs/kpIVNINNzxq
      uE7dTihVCqKfYBT0sMLk8psMAtAE8rDqQEEgD1k/Ck5M0kT4ArJAuGqfDRWdo2FI
      nuYEJQbjaXV0kT3txOFaIPijzwKBgQDPgPeJwjxNyZxoLX5ncvQ2vpzIGRVkX/k7
      9dHTb0h0lCJv7xgYyRrwftbmzK8wZMUGPRW8XmkgFps3yHm9AEFBcP0QaJBv+Ae2
      HZJsmqvDV5+lOVLk7gnR1/RrR84JWrVUwgFMOriy1NgX/qUBlejZBwRiqz2tw/o3
      ulr5F6wN9QKBgHyEyL45rx21BtFtD4rNWKYsochcs+yOnGo+8zZaEGvR9SaVjo0j
      oLIFagiFV3rnufoTWdZBj0NNeaOZ2sWL7iGEtYroCYl4eF3zn1dEAN7auHZCLn3P
      9kCx2b6dCTESkCmmFH90YDvB5lf5J2ImFXMKkICYEeHc7SW6zGmaXxDNAoGBALWM
      5QfGxfRZPVt40mu4jCuJwqrgJ3NW9T2c6iTP7Njy8t50luS4r7VThLsSwwTYZfn7
      YBUblWbZ4JyB7uGKY43aSdAdbKJKpJSWcxJKkZWsCKYK7ZgXHMhY5iUnAgH1N0od
      I/2KMydkSl1UExK8EqowFYouwRxTp40yo33lVEgxAoGAKhLjO01Vc4ygXgPiH2Sv
      oYwttsBhiatjwFHuD6SMsS7Ww5JFi0/s4FQXiDXMAlnw1TSMTX8AUg9hbG8NxUov
      5w9Wv3IW3nZa6C/mab6VpdHJNyRCo+WD6iVcUxJAve212cxmtiBDiCS2re8Ro1Vj
      DHjrHPN/Zt03GHDdlZvkNJw=
      -----END PRIVATE KEY-----
    EOF
  }
}

run "validate_network_success" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24", dns = "dns.google.com", domain = "cluster.local", }
  }
}

run "validate_network_cidr_failed" {
  command = plan

  variables {
    network = { cidr = null, dns = "dns.google.com", domain = "cluster.local", }
  }

  expect_failures = [ var.network ]
}

run "validate_network_dns_failed" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24" , dns = null, domain = "cluster.local", }
  }

  expect_failures = [ var.network ]
}

run "validate_network_domain_failed" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24", dns = "dns.google.com", domain = "", }
  }

  expect_failures = [ var.network ]
}

run "validate_cert_incorrect_failed" {
  command = plan

  variables {
    cert = {
      ca  = null
      key = null
    }
  }
  
  expect_failures = [ var.cert ]
}
