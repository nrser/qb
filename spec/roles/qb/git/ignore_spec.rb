using NRSER

describe_qb_role 'qb/git/ignore' do
  include_context :before_all_clear_temp_roles
  
  describe "dest dir doesn't exist" do
    before :all do
      @name = 'git/ignore/new'
      @dest = TEMP_ROLES_DIR / @name
      @ignore_name = 'QB'
      
      Cmds.new(
        './bin/qb qb/git/ignore <%= opts %> <%= dest %>',
        chdir: QB::ROOT,
        kwds: {
          dest: @dest,
          opts: {
            name: @ignore_name,
          },
        },
      ).stream!
      
      @dest_ignore_path = @dest / '.gitignore'
      
      @src_ignore_path = QB::ROOT.join \
        'roles',
          'qb',
            'git',
              'ignore',
                'files',
                  'gitignore',
                    "#{ @ignore_name }.gitignore"
      
      @expected_dest_ignore_contents = binding.erb <<~END
        ##############################################################################
        # BEGIN QB.gitingore
        #
        <%= @src_ignore_path.read.chomp %>
        #
        # END QB.gitingore
        ##############################################################################
      END
    end
    
    describe '.gitignore file' do
      subject { @dest_ignore_path }
      
      it do
        is_expected.to exist
      end
      
      describe 'contents' do
        subject { super().read }
        it { is_expected.to eq @expected_dest_ignore_contents }
      end
    end
    
    describe "when run again" do
      before :all do
        Cmds.new(
          './bin/qb qb/git/ignore <%= opts %> <%= dest %>',
          chdir: QB::ROOT,
          kwds: {
            dest: @dest,
            opts: {
              name: @ignore_name,
            },
          },
        ).stream!
      end
      
      describe '.gitignore file' do
        subject { @dest_ignore_path }
        
        it do
          is_expected.to exist
        end
        
        describe 'contents' do
          subject { super().read }
          it { is_expected.to eq @expected_dest_ignore_contents }
        end
      end
      
    end
  end
end
