class Testimonial
  LIST = [
#     {
#       enabled: :admin_only,
#       name: "Owen",
#       course: "Computer Science, 2nd Year",
#       message: %Q{
# Tcal is the sexiest tool to replace TCD's pathetic attempt at getting a useful calendar, MyDay.

# It's great that one CS student can write a better system, for free, than the one TCD undoubtedly paid far too much for.
#       }
#     },
    {
      enabled: true,
      name: "Sam",
      course: "2nd year BESS",
      message: %Q{
It's beautiful
      }
    },
    {
      enabled: true,
      name: "Eoin",
      course: "3rd year Science",
      message: %Q{
It's f**king sweet
      }
    },
    {
      enabled: true,
      name: "Fiona",
      course: "1st year BESS",
      message: %Q{
Just syncing it now 👍  thanks... so handy!
      }
    },
    {
      enabled: true,
      name: "Patrick",
      course: "2nd year Sociology and Social Policy",
      message: %Q{
Unbelievably handy
      }
    },
    {
      enabled: true,
      name: "Cian",
      course: "4th year Engineering",
      message: %Q{
Tcal is dead handy
      }
    },
    {
      enabled: true,
      name: "Aaron",
      course: "2nd year Business and German",
      message: %Q{
I actually turn up to lectures on time...
      }
    },
    {
      enabled: true,
      name: "Conor",
      course: "2nd year BESS",
      message: %Q{
Mind=Blown.
      }
    },
    {
      enabled: true,
      name: "Conor",
      course: "1st year Maths and Economics",
      message: %Q{
An absolute godsend
      }
    },
    {
      enabled: true,
      name: "Cian",
      course: "2nd year Medicine",
      message: %Q{
How has trinity not had this before?
      }
    },
    {
      enabled: true,
      name: "Jack",
      course: "2nd year BESS",
      message: %Q{
...much quicker, concise, better layout...
      }
    },
    {
      enabled: true,
      name: "Ciaran",
      course: "4th year Computer Science and Business",
      message: %Q{
This finally happened.
      }
    },
  ]

  STANDARD_LIST = LIST.select { |t| t[:enabled] == true }.freeze
  ADMIN_LIST = LIST.select { |t| t[:enabled] }.freeze

  def self.sample(n, user=nil)
    (user.try(:is_admin?) ? ADMIN_LIST : STANDARD_LIST).sample(n)
  end
end
