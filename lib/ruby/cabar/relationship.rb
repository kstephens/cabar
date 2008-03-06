require 'cabar/base'


module Cabar

  # A represents two Components in relationship through
  # a Facet.
  #
  class Relationship < Base
    # The first participant.
    attr_accessor :participant_1
    # The first participant's role.
    attr_accessor :role_1

    # The second participant.
    attr_accessor :participant_2
    # The second participant's role.
    attr_accessor :role_2

    # The facet.
    attr_accessor :facet

    # Returns true if the Relationship is enabled.
    def enabled?
      o = _options
      o[:enabled].nil? || o[:enabled]
    end

    # Called when a Relationship
    # is specified for a Facet.
    def attach_facet! f
      f.attach_relationship! self
    end

    # Render the Relationship with the Renderer.
    #
    # Subclasses may override this.
    def render r
    end

    # Used for YAML formatting and general inspection.
    #
    # Subclasses may override this.
    def to_a
      [
        [ :class,    self.class.to_s ],
        [ :facet,    facet.to_s ],
        [ :participant_1,    participant_1 ],
        [ :role_1,   role_1.to_s ],
        [ :participant_2,    participant_2 ],
        [ :role_2,   role_2.to_s ],
        # [ :_options,  _options ],
      ]
    end

  end # class

end # module


