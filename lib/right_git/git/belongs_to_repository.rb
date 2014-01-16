module RightGit::Git
  module BelongsToRepository
    attr_reader :repo

    def logger
      repo.logger
    end
  end
end
