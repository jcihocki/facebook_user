require 'json'
require 'base64'
require 'openssl'

module StartupGiraffe
  module FacebookUser
    class Cookie
      
      def initialize cookie, secret
        @secret = secret
        @payload = JSON base64_url_decode( cookie.split('.').last )
        self
      end
      
      def to_s
        "#{encoded_signature}.#{encoded_payload}"
      end
      
      def cache
        @payload['cache']
      end
      
      def add_to_cache hash
        if @payload['cache']
          @payload['cache'].merge! hash
        else
          @payload['cache'] = hash
        end
      end
        
      private
      
        def signature
          OpenSSL::HMAC.digest OpenSSL::Digest::SHA256.new, @secret, encoded_payload
        end

        def base64_url_decode str
          str += '=' * (4 - str.length.modulo(4))
          str = str.gsub('-', '+').gsub('_', '/')
          Base64.decode64 str
        end
      
        def base64_url_encode str
          Base64.encode64( str ).gsub('+', '-').gsub('/', '_').gsub(/[\n\r\=]/, '')
        end
        
        def encoded_signature
          base64_url_encode signature
        end
        
        def encoded_payload
          base64_url_encode @payload.to_json
        end
      
    end
  end
end