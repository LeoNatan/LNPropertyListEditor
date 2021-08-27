#!/usr/bin/ruby

require 'fileutils'

include_path = File.expand_path("HexFiendFramework/include/")
src_path = File.expand_path("HexFiendFramework/src/")

#cleanup
Dir.foreach(src_path) do |f|
  fn = File.join(src_path, f)
  FileUtils.rm_rf(fn) if f != '.' && f != '..'
end

Dir.foreach(include_path) do |f|
  fn = File.join(include_path, f)
  FileUtils.rm_rf(fn) if f != '.' && f != '..'
end

Dir.mkdir(File.join(include_path, "HexFiend"))

require 'xcodeproj'

project_path = 'HexFiend/HexFiend_2.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.select do |target|
  target.name == "HexFiend_Framework"
end.first

output_project_path = Pathname(File.expand_path("HexFiendFramework"))
output_project = Xcodeproj::Project.new(output_project_path.join("HexFiend.xcodeproj"))
output_target = output_project.new_target(:framework, 'HexFiend', :osx, '10.11')

#headers
output_headers_group = output_project.new_group("Headers")

files = target.headers_build_phase.files.to_a.map do |pbx_header_file|
  pbx_header_file
end.select do |pbx_header_file|
  not(pbx_header_file.file_ref.real_path.to_s.include?("PrivilegedHelper"))
end.each do |pbx_header_file|
  file = pbx_header_file.file_ref.real_path

  output_file_reference = output_headers_group.new_file(file)
  output_build_file = output_target.headers_build_phase.add_file_reference(output_file_reference)

  file2 = file.relative_path_from(src_path)
  File.symlink(file2, File.join(src_path, File.basename(file)))

  file3 = file.relative_path_from(File.join(include_path, "HexFiend"))
  File.symlink(file3, File.join(File.join(include_path, "HexFiend"), File.basename(file)))

  if pbx_header_file.settings.nil?
  else
    output_build_file.settings = pbx_header_file.settings
  end
end

#manual
file = Pathname(File.expand_path("HexFiend/framework/tests/HFTest.h"))

output_file_reference = output_headers_group.new_file(file)
output_target.add_file_references([output_file_reference])

file2 = file.relative_path_from(src_path)
File.symlink(file2, File.join(src_path, File.basename(file)))
file3 = file.relative_path_from(File.join(include_path, "HexFiend"))
File.symlink(file3, File.join(File.join(include_path, "HexFiend"), File.basename(file)))

#sources
output_sources_group = output_project.new_group("Sources")

files = target.source_build_phase.files.to_a.map do |pbx_build_file|
  pbx_build_file.file_ref.real_path
end.select do |path|
  path.to_s.end_with?(".h", ".m", ".mm", ".swift")
end.select do |path|
  not(path.to_s.include?("PrivilegedHelper"))
end.select do |path|
  File.exists?(path)
end.each do |file|
  output_file_reference = output_sources_group.new_file(file)
  output_target.add_file_references([output_file_reference])
  
  file2 = file.relative_path_from(src_path)
  File.symlink(file2, File.join(src_path, File.basename(file)))
end

infoPlistFile = Pathname(File.expand_path("HexFiend/framework/HexFiend_Framework-Info.plist")).relative_path_from(output_project_path)
infoPlistPreprocessFile = Pathname(File.expand_path("HexFiend/version.h")).relative_path_from(output_project_path)
output_target.build_configurations.each do |config|
config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] = ["HF_NO_PRIVILEGED_FILE_OPERATIONS=1"]
config.build_settings["INFOPLIST_PREFIX_HEADER"] = infoPlistPreprocessFile.to_s
config.build_settings["INFOPLIST_FILE"] = infoPlistFile.to_s
config.build_settings["INFOPLIST_PREPROCESS"] = target.build_configurations.first.build_settings["INFOPLIST_PREPROCESS"]
config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.ridiculousfish.HexFiend-Framework"
config.build_settings["WARNING_CFLAGS"] = "-Wno-conditional-uninitialized"
end

output_project.save(output_project_path.join("HexFiend.xcodeproj"))