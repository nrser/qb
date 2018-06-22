# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

require 'yaml'
require 'fileutils'

# Deps
# -----------------------------------------------------------------------

# Need {Array#split}
require 'active_support/core_ext/array/grouping'


# Namespace
# =======================================================================

module  QB
module  Helm


# Definitions
# =======================================================================

# Tools for handling Helm install & update "dry runs" (`--dry-run`).
# 
module DryRun
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # ========================================================================
  
  # Write a manifest to a file in `dest_dir`, organized by the chart it's a
  # part of. Figures that out by parsing the manifest.
  # 
  # @param [String] manifest:
  #   The Kubernetes resource manifest output from a Helm dry run.
  # 
  # @param [String | Pathname] dest_dir:
  #   The base directory to write files to.
  # 
  # @return [true]
  #   If the manifest was successfully written.
  # 
  # @return [false]
  #   If we failed to write the manifest (logs an error in this case).
  # 
  def self.write_manifest manifest:, dest_dir:
    parse = begin
      YAML.load manifest
    rescue Exception => error
      logger.error "Failed to load resource manifest",
        { manifest: manifest },
        error
      
      return false
    end
    
    unless Hash === parse
      logger.error "Parse is not a hash!",
        manifest: manifest,
        parse: parse
      
      return false
    end
    
    kind = parse['kind'].downcase
    name = parse.dig 'metadata', 'name'
    # app = parse.dig 'metadata', 'labels', 'app'
    chart = parse.dig 'metadata', 'labels', 'chart'
    
    path = dest_dir.to_pn.join *[chart, "#{ name }.#{ kind }.yaml"].compact
    
    FileUtils.mkdir_p( path.dirname ) unless path.dirname.exist?
    
    path.write manifest
    
    return true
  end # .write_manifest
  
  
  # Extract Kubernetes resource manifests from Helm's dry-run output.
  # 
  # @param [String] cmd_output
  #   Output of a `helm [install|update] --dry-run ...` command.
  # 
  # @return [Array<String>]
  #   List of individual manifests.
  # 
  def self.extract_manifests cmd_output:
    lines = cmd_output.enum_for :lines
    
    while lines.next != "MANIFEST:\n" do; end
    
    manifest_lines = []
    
    until lines.peek.end_with? "Happy Helming!\n"
      manifest_lines << lines.next
    end
    
    manifests = manifest_lines.
      split( "---\n" ).
      map( &:join ).
      reject { |manifest| /\A\s*\z/m =~ manifest }
  end # .extract_manifests
  
  
  # Extract individual manifests from Helm's dry-run output and write them
  # in an organized fashion to a destination directory so you can inspect or
  # run tests against them.
  # 
  # @see .extract_manifests
  # @see .write_manifest
  # 
  # @param cmd_output: (see .extract_manifests)
  # @param dest_dir: (see .write_manifest)
  # 
  # @return (see .extract_manifests)
  # 
  def self.extract_and_write_manifests cmd_output:, dest_dir:
    dest_dir = dest_dir.to_pn
    
    manifests = extract_manifests cmd_output: cmd_output
    
    manifests.each do |manifest|
      write_manifest manifest: manifest, dest_dir: dest_dir
    end
    
    manifests
  end # .extract_and_write_manifests
  
end # module DryRun


# /Namespace
# =======================================================================

end # module Helm
end # module QB
