require 'spec_helper'
describe 'babag' do
  context 'with default values for all parameters' do
    it { should contain_class('babag') }
  end
end
