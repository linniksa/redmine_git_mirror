module RedmineGitMirror
  module Patches
    unloadable
    module RepositoriesHelperPatch

      def git_mirror_field_tags(form, repository)
        content_tag('p', form.text_field(
          :url,
          :size => 60,
          :required => true,
          :disabled => !repository.safe_attribute?('url'),
          ) +
          content_tag('em', l(:text_git_mirror_url_note), :class => 'info')
        ) +
        content_tag('p', form.text_field(
          :branches_to_fetch,
          :size => 60,
          :required => false,
          :disabled => !repository.safe_attribute?('branches_to_fetch'), name: 'repository[extra_info][branches_to_fetch]'
          ) +
          content_tag('em', l(:text_git_mirror_branches_to_fetch_note), :class => 'info')
        )
      end
    end
  end
end
