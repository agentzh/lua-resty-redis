# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua::Stream;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

add_block_preprocessor(sub {
    my $block = shift;

    if (!defined $block->http_only) {
        if ($ENV{TEST_SUBSYSTEM} eq "stream") {
            if (!defined $block->stream_config) {
                $block->set_value("stream_config", $block->global_config);
            }
            if (!defined $block->stream_server_config) {
                $block->set_value("stream_server_config", $block->server_config);
            }
            if (defined $block->internal_server_error) {
                $block->set_value("stream_respons", "");
            }
        } else {
            if (!defined $block->http_config) {
                $block->set_value("http_config", $block->global_config);
            }
            if (!defined $block->request) {
                $block->set_value("request", <<\_END_);
GET /t
_END_
            }
            if (!defined $block->config) {
                $block->set_value("config", "location /t {\n" . $block->server_config . "\n}");
            }
            if (defined $block->internal_server_error) {
                $block->set_value("error_code", 500);
                $block->set_value("ignore_response_body", "");
            }
        }
    }
});

our $GlobalConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: basic
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis"
            ngx.say(redis._VERSION)
        ';
--- response_body_like chop
^\d+\.\d+$
--- no_error_log
[error]
