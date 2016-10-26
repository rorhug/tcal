class Testimonial
  LIST = [
#     {
#       enabled: :admin_only,
#       name: "Owen Shepherd",
#       course: "Computer Science, 2nd Year",
#       message: %Q{
# Tcal is the sexiest tool to replace TCD's pathetic attempt at getting a useful calendar, MyDay.

# It's great that one CS student can write a better system, for free, than the one TCD undoubtedly paid far too much for.
#       }
#     },
    {
      enabled: true,
      name: "Sam Daly",
      course: "2nd year BESS",
      message: %Q{
It's beautiful
      }
    },
    {
      enabled: true,
      name: "Eoin McMahon",
      course: "3rd year Science",
      message: %Q{
It's f**king sweet
      }
    },
    {
      enabled: true,
      name: "Fiona Hughes",
      course: "1st year BESS",
      message: %Q{
Just syncing it now 👍  thanks... so handy!
      }
    },
    {
      enabled: true,
      name: "Patrick Maher",
      course: "2nd year Sociology and Social Policy",
      message: %Q{
Unbelievably handy
      }
    },
    {
      enabled: true,
      name: "Cian Flynn",
      course: "2nd year Engineering",
      message: %Q{
Tcal is dead handy
      }
    },
    {
      enabled: true,
      name: "Aaron McDermott",
      course: "2nd year Business and German",
      message: %Q{
I actually turn up to lectures on time
      }
    },
    {
      enabled: true,
      name: "Conor Totterdell",
      course: "2nd year BESS",
      message: %Q{
Mind=Blown.
      }
    },
    {
      enabled: true,
      name: "Conor Totterdell",
      course: "1st year Maths and Economics",
      message: %Q{
An absolute godsend
      }
    },
  ]

  STANDARD_LIST = LIST.select { |t| t[:enabled] == true }.freeze
  ADMIN_LIST = LIST.select { |t| t[:enabled] }.freeze

  def self.sample(n, user=nil)
    (user.try(:is_admin?) ? ADMIN_LIST : STANDARD_LIST).sample(n)
  end
end
