#!/usr/bin/env ruby -U
# encoding: UTF-8

class F
  attr_reader :path
  attr_reader :filename
  def initialize(path)
    @path = path
  end
  
  def header?
    @path.end_with? '.h'
  end
  
  def filename
    File.basename path
  end
  
  def content
    if @content.nil?
      @content = ''
      File.open(@path, 'r') do |f|
        @content = f.read
      end
    else
      @content
    end
  end
  
  def imports skip_selfheader = false
    if @imports.nil?
      @imports = []
      begin
        imports = self.content.scan /^\s*\#import\s+(?:"|<)(?<import_name>[\w\.\+_\\\/]+)(?:"|>)/m
        @imports = imports.flatten.map{|v| File.basename(v)} if imports
      rescue Exception => e
        puts "#{e.message} => #{@path}"
      end
    end
    if skip_selfheader && !self.header?
      @imports.reject! do |item|
        File.basename(item, '.h').downcase == File.basename(self.filename, '.m').downcase
      end
    end
    @imports
  end
  
  def classes
    unless header?
      return []
    end
    if @classes.nil?
      @classes = []
      classes = self.content.scan /@interface\s+(?<class_name>\w+)(\s+|:|\<|\()/m
      @classes = classes.flatten if classes
    end
    @classes
  end
end

def files dir
  Dir[File.join(File.expand_path(dir), '**/*.{h,m,mm,pch}')]
end

## Workflow

files = []
files(Dir.pwd).each do |path|
  files << F.new(path)
end

classes_table = {}
imports_table = {}
files.each do |file|
  file.classes.each do |cla|
    classes_table[cla] ||= []
    classes_table[cla] << file
  end
  file.imports.each do |imp|
    imports_table[imp] ||= []
    imports_table[imp] << file.filename
  end
end

orphans = {}
classes_table.each do |cla, files|
  imps = []
  files.each do |f|
    imps << f if imports_table[f.filename].nil?
  end
  orphans[cla] = files.map {|f| f.path} if imps.count > 0
end

if orphans.count > 0
  puts "Orphan classes"
  orphans.each do |cla, files|
    puts "Class #{cla} in files"
    puts "\t" + files.join("\n\t")
  end
else
  puts "Everything is clear"
end
