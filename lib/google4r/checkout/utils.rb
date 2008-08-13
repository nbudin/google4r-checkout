#--
# Project:   google4r
# File:      lib/google4r/checkout/utils.rb 
# Author:    Tony Chan <api.htchan@gmail.com>
# Copyright: (c) 2007 by Tony Chan
# License:   MIT License as follows:
#
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the 
# following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
#++
# This file contains the classes and modules that are used by the command
# generating code.

require 'cgi'
require 'openssl'
require 'base64'

module Google4R #:nodoc:
  module Checkout #:nodoc:
    # HTML Signing
    #
    # Args:
    # - params -- html form parameters
    # - merchant_key -- Google Checkout merchant key
    #
    # Returns:
    # - signature -- The base-64 encoded result of hashing the serialized
    #                parameters with the merchant key
    #
    # Example
    # -------
    # require 'google4r/checkout/utils'
    #
    # Google4R::Checkout.sign({:a=>'123', :b=>'456'}, 'merchantkey')
    # => "5qBQYatFZk5BMS1hm5gSUS+9yrg="
    #
    def self.sign(params, merchant_key)
      raise "params must be a Hash (e.g. {param1 => value1, param2 => value2, ...})" unless params.kind_of? Hash
      raise "merchant_key must be a String" unless merchant_key.kind_of? String
      
      # Remove unwanted parameters
      params.delete_if do |key, value|
        key = key.to_s
        key == '_charset_' || key == 'analyticsdata' ||
        key == 'urchindata' || key =~ /^(.+\.)*[xy]$/
      end
      
      # Strip away whitespaces and url-encode the values
      params.each do |key, value|
        params[key] = CGI::escape(value.to_s.strip)
      end
      
      # Sort parameters alphabetically by value and then key
      params_arr = params.sort do |x, y|
        if x[0] != y[0] then
          x[0].to_s <=> y[0].to_s
        else
          x[1].to_s <=> y[1].to_s
        end
      end
    
      # Create parameter string to be hashed 
      params_str = ''
      params_arr.each do |x|
        if params_str != '' then params_str += '&' end
        params_str += x[0].to_s + '=' + x[1]
      end

      # Generate hashed signature
      signature = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new,
                                       merchant_key,
                                       params_str)
    
      # Encode the hash value in Base64 before returning it
      return Base64.encode64(signature).chomp
    end
  end
end
