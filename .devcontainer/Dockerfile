FROM library/ruby:bookworm

RUN apt-get update && \
  apt-get install -y build-essential git curl libpq-dev neovim && \
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get install -y nodejs 
  
RUN gem update --system && \
  gem install bundler rails rspec guard-rspec ruby-lsp pry byebug rubocop
