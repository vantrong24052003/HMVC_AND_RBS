# frozen_string_literal: true

# Stage-specific configuration - dùng ENV vars
set :stage, "staging"
set :rails_env, "staging"
set :branch, "staging"

# Server Configuration
server "34.55.113.241",
       user:        "trong.doan",
       roles:       %w[app db web],
       ssh_options: {
         keys:          %w[/home/vantrong/.ssh/id_rsa],
         forward_agent: false,
         auth_methods:  %w[publickey],
       }
