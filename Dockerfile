FROM ruby:2.6.3

# Install required packages:
RUN apt-get update -qq \
    && apt-get install -y nodejs postgresql-client

# Get the bundle installed:
RUN mkdir /datagovuk_publish
WORKDIR /datagovuk_publish
COPY .ruby-version /datagovuk_publish/.ruby-version
COPY Gemfile /datagovuk_publish/Gemfile
COPY Gemfile.lock /datagovuk_publish/Gemfile.lock
RUN bundle install

# Move the rest of the code in:
COPY . /datagovuk_publish

# Start the main process.
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
