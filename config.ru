require './lib/rubor'

use Rack::Reloader
use Rack::Static, root: 'public/', urls: ['/images'], index: 'index.html'

run Rubor::Application