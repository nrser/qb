
def docker; QB::Docker::CLI; end

def name; docker.image_names.first; end
