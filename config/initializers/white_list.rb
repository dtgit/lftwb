# WhiteListHelper.attributes[nil] = %w(id class style align)
# WhiteListHelper.attributes['u'] = %w(class)
# WhiteListHelper.attributes['strike'] = %w(class)
# WhiteListHelper.attributes['object'] = %w(classid codebase width height align id salign flashvars)
# WhiteListHelper.attributes['param']  = %w(name value type)
# WhiteListHelper.attributes['embed']  = %w(src quality salign scale bgcolor align menu pluginspage type width height wmode flashvars)
# WhiteListHelper.attributes['iframe'] = %w(src frameborder width height)

# Failing because of some plugin path issue on ubuntu
# WhiteListHelper.tags.merge %w(table td th)
# WhiteListHelper.attributes.merge %w(id class style)