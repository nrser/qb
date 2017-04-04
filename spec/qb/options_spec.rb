require 'spec_helper'

describe QB::Options do  
  describe '.parse!' do
    context "empty role" do
      role = test_role "empty"
      
      context "empty args" do
        let(:parsed)    { QB::Options.parse! role, [] }
        let(:role_opts) { parsed[0] }
        let(:qb_opts) { parsed[1] }
        
        it "returns no role options" do
          expect(role_opts.empty?).to be true
        end
        
        it "returns default qb options" do
          expect(qb_opts).to eq QB::Options::QB_DEFAULTS
        end
      end # empty args
    end # empty role
    
    context "required option role" do
      role = test_role "required_option", ['required_option']
      
      it "has a required option" do
        expect(role.options.length).to eq 1
        expect(role.options[0].required?).to be true
      end
      
      context "empty args" do
        role_opts, qb_opts = QB::Options.parse! role, "-r blah".shellsplit
        
        it "assigns the value" do
          expect(role_opts.length).to be 1
          
          option = role_opts['required']
          
          expect(option).to be_a QB::Options::Option
          expect(option.value).to eq 'blah'
        end
      end # empty args
    end # required_option
  end # .parse!
  
  describe "#parse_ansible!" do
    
    context "required options role" do
      role = test_role "required_option", ["required_option"]
      
      it "parses a boolean ansible option to have true value" do
        options = QB::Options.new role, "--ANSIBLE_ask-vault-pass".shellsplit
        
        expect(options.ansible.length).to be 1
        expect(options.ansible.key? 'ask-vault-pass').to be true
        expect(options.ansible['ask-vault-pass']).to be true
        expect(options.instance_variable_get(:@argv)).to eq []
      end
      
      it "parses a string ansible option to correct value" do
        options = QB::Options.new role, "--ANSIBLE_tags=blah".shellsplit
        
        expect(options.ansible.length).to be 1
        expect(options.ansible.key? 'tags').to be true
        expect(options.ansible['tags']).to eq 'blah'
        expect(options.instance_variable_get(:@argv)).to eq []
      end
    end # required options role
    
  end # #parse_ansible!
end # QB::Options
