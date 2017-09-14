# app/middleware/catch_json_parse_errors.rb
# from https://robots.thoughtbot.com/catching-json-parse-errors-with-custom-middleware
class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    # rescue ActionDispatch::ParamsParser::ParseError => error
    rescue ActionDispatch::Http::Parameters::ParseError => error
      if env['HTTP_ACCEPT'] =~ /application\/json/ ||
          env['CONTENT_TYPE'] =~ /application\/json/
        error_output = "Malformed JSON content: #{error}"
        return [
            400, { "Content-Type" => "application/json" },
            [ { status: 400, error: error_output }.to_json ]
        ]
      else
        raise error
      end
    end
  end
end
