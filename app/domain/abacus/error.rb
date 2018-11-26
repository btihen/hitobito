#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Abacus::Error

  attr_reader :code, :text

  def initialize(error, message)
    @error = error
    @message = message
  end

end