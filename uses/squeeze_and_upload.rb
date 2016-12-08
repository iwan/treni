require 'aws-sdk'
require 'date'

Aws.config.update({
  region: 'eu-west-1',
  credentials: Aws::Credentials.new(ENV.fetch'TRAIN_AWS_S3_KEY_ID', ENV.fetch'TRAIN_AWS_S3_SECRET')
})



folders = true
if folders
  yesterday = (Date.today-1).strftime("%Y-%m-%d")
  statuses_dir = ENV.fetch "TRAIN_STATUSES_DIR"

  Dir.chdir statuses_dir
  local_date_dirs = Dir.glob("*").keep_if{|f| File.directory?(f)}
  puts local_date_dirs.size
  local_date_dirs = local_date_dirs.keep_if{|f| f < yesterday} # escludo oggi e ieri
  puts local_date_dirs.size


  s3 = Aws::S3::Resource.new
  bucket = s3.bucket('train-statuses')
  local_date_dirs.each do |bname|
    # bname: "2016-02-03"
    cfn   = "#{bname}.tar.gz"      # "2016-02-03.tar.gz"
    obj   = bucket.object(cfn)
    if obj.exists?
      puts "'#{cfn}' is already present on S3"
    else
      # cfn_path = File.join(File.dirname(loc_dir), cfn)
      if File.exists?(cfn)
        puts "#{cfn} already present locally"
      else
        puts "#{cfn} not present locally, squeezing..."
        output = system "tar -zcvf #{cfn} #{bname}"
        # puts "Output is:\n#{output}\n\n"

      end
      puts "Uploading '#{bname}' on S3..."
      obj.upload_file(cfn)
    end

  end
  # remote_date_files = bucket.objects.map{|obj| obj.key}
  # puts local_date_dirs.inspect
  # puts remote_date_files.inspect


else
  # copia dalla cartella che sta dentro Dropbox tutti i file
  # compressi (tipo "2016-02-03.tar.gz") su AWS::S3
  statuses_dir = File.join(Dir.home, "Dropbox", "treni", "statuses")
  local_date_files = Dir.glob(File.join(statuses_dir,"*.tar.gz"))
  # local_date_files = [local_date_files.first]
  s3 = Aws::S3::Resource.new
  bucket = s3.bucket('train-statuses')
  local_date_files.each do |loc_file|
    obj   = bucket.object(File.basename(loc_file))
    bname = File.basename(loc_file)
    if obj.exists?
      puts "'#{bname}' is already present on S3"
    else
      puts "Uploading '#{bname}' on S3..."
    end
    obj.upload_file(loc_file) if !obj.exists?
  end
end



# tar -zcvf archive-name.tar.gz directory-name



# STEPS:
# - parsare la dir con le Date
# - se la data è precedente a oggi-1 e la data (2016-04-07.tar.gz)
#   non è presente su aws::s3, allora comprimi e carica

# dir
