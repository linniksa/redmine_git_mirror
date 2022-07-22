module RedmineGitMirror
    class HookListener < Redmine::Hook::ViewListener
        render_on :view_repositories_navigation, partial: 'repositories/git_mirror_navigation'

        def view_layouts_base_html_head(context={})
            return stylesheet_link_tag(:redmine_git_mirror, :plugin => 'redmine_git_mirror')
        end
    end
end
