s/num_threads\">[0-9]+/num_threads\">1/g
s/initial delay\">[0-9]+/initial delay\">0/g
s/Start users count\">[0-9]+/Start users count\">1/g
s/Start users count burst\">[0-9]+/Start users count burst\">1/g
s/Start users period\">[0-9]+/Start users period\">1/g
s/Stop users count\">[0-9]+/Stop users count\">1/g
s/Stop users period\">[0-9]+/Stop users period\">1/g
s/flighttime\">[0-9]+/flighttime\">480/g
s/rampUp\">[0-9]+/rampUp\">1/g
s/on_sample_error\">[a-z]+/on_sample_error\">startnextloop/g
s/Argument.value\">regression/Argument.value\">smoke/g
s/Hold\">[0-9]+/Hold\">8/g
s/Argument.value\">sm-controller/Argument.value\">tea/g
