require 'myrb'

# project = Myrb::Project.new(File.expand_path('.'))
project = Myrb::Project.new('/Users/camertron/workspace/camertron/ohey')
file = project.find('lib/ohey/solaris2.trb')
# file = project.find('examples/component.trb')
# puts file.rewritten_source
puts file.rbs_source
file.write_rbs
# puts file.annotated_ast
# puts file.annotations.inspect
