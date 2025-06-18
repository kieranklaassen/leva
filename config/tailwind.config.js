const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    // Include absolute paths to ensure engine files are scanned
    __dirname + '/app/helpers/**/*.rb',
    __dirname + '/app/javascript/**/*.js',
    __dirname + '/app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    // Background colors
    'bg-gray-100', 'bg-gray-700', 'bg-gray-800', 'bg-gray-900', 'bg-gray-950',
    'bg-blue-100', 'bg-blue-600', 'bg-blue-700',
    'bg-green-100',
    'bg-indigo-600', 'bg-indigo-700',
    'bg-red-100', 'bg-red-900',
    'bg-yellow-100',
    
    // Text colors
    'text-gray-300', 'text-gray-400', 'text-gray-500', 'text-gray-800',
    'text-blue-300', 'text-blue-400', 'text-blue-800',
    'text-green-300', 'text-green-400', 'text-green-800',
    'text-indigo-100', 'text-indigo-200', 'text-indigo-300', 'text-indigo-400', 'text-indigo-600',
    'text-lime-500', 'text-orange-500',
    'text-red-100', 'text-red-500', 'text-red-800',
    'text-yellow-400', 'text-yellow-500', 'text-yellow-800',
    
    // Border colors
    'border-gray-700', 'border-gray-800', 'border-red-700',
    
    // Hover states
    'hover:bg-gray-700', 'hover:bg-gray-800', 'hover:bg-blue-700', 'hover:bg-indigo-700',
    'hover:text-blue-300', 'hover:text-indigo-300',
    
    // Gradient colors
    'from-blue-500', 'from-blue-600', 'from-green-500', 'from-green-600',
    'to-indigo-600', 'to-indigo-700', 'to-teal-600', 'to-teal-700',
    
    // Background gradient
    'bg-gradient-to-r'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}