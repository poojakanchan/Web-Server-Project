
require 'base64'
require 'digest'

class HtaccessChecker

  attr_reader :path,:request,:doc_root, :file_path, :htpasswdcontent

  def initialize(path, request,document_root)
   @path = path
   @request = request
   @doc_root = document_root
   @content =Hash.new
   @htpasswdcontent= Hash.new
 end



 def protected?
  flag = false
  appended_path = ""
  @path.split(File::SEPARATOR).map do |subdir|
   appended_path.concat(subdir=="" ? File::SEPARATOR : File::SEPARATOR + subdir)
   if(File.exists?(@doc_root + appended_path + "/.htaccess")) 
       @file_path = @doc_root + appended_path +  "/.htaccess"    
       flag = true
       break
    end
  end
  flag
 end

 def can_authorized?
   request.headers.has_key?("Authorization")
 end

 def authorized?
   flag = false

   @content = parse_file
   encryptheader = request.headers.get("Authorization").split(" ")[1]
   if ! encryptheader.nil?
      decryptheader = Base64.decode64(encryptheader)
      key,value = decryptheader.split(':')
      puts "key value from header" + key + " " + value
      @htpasswdcontent = htpasswd
     
      if htpasswdcontent[key] == Digest::SHA1.base64digest(value)
             flag = true
      end

   end
 end



def parse_file
   file_lines = IO.readlines(file_path)
   file_content = Hash.new
   file_lines.each do |line|
      key, value = line.split(" ")
      value =  value.chomp("\"")
      if value[0,1] == "\""
         value.slice!(0)
      end
      file_content[key.strip] = value.strip
   end
  file_content
end


def htpasswd
  htpasswdlist = Hash.new
  htpasswd = IO.readlines(@content["AuthUserFile"])
  htpasswd.each do |line|
    key, value = line.split(':')
    value = value.gsub(/{SHA}/,'' )
    htpasswdlist[key.strip] = value.strip
  end

  htpasswdlist
end

end
