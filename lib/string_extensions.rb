require 'cgi'

class String
  def fb_sanitize()
    ActionController::Base.helpers.sanitize(CGI.unescapeHTML(self), :tags => %w(fb:name del dd h3 address big sub tt a ul h4 cite dfn h5 small kbd code
       b ins h6 sup pre strong blockquote acronym dt br p div samp
       li ol var em h1 i abbr h2 span hr), :attributes => %w(name href cite class title src height datetime alt abbr width capitalize firstnameonly linked uid))
  end

  def sanitize(options={})
    ActionController::Base.helpers.sanitize(CGI.unescapeHTML(self), options)
  end

  def sanitize_standard()
    self.gsub!(/<!--(.*?)-->[\n]?/m, "")
    ActionController::Base.helpers.sanitize(self, :tags => %w(del, dd, h3, address, big, sub, tt, a, ul, h4, cite, dfn, h5, small, kbd, code,
       b, ins, h6, sup, pre, strong, blockquote, acronym, dt, br, p, div, samp,
       li, ol, var, em, h1, i, abbr, h2, span, hr), :attributes => %w(name, href, cite, class, title, src, height, datetime, alt, abbr, width))
  end
end
