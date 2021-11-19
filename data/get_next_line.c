#include "get_next_line.h"
#include <stdlib.h>
#include <unistd.h>

static void	ft_set_fd(t_line_reader *r, int new_fd)
{
	if (new_fd != r->fd)
	{
		r->cursor = 0;
		r->count = 0;
		r->fd = new_fd;
	}
}

static long	ft_read(t_line_reader *r)
{
	if (r->cursor == r->count)
	{
		r->count = read (r->fd, r->buff, BUFFER_SIZE);
		r->cursor = 0;
	}
	return (r->count);
}

static int	ft_copy_buff(t_line_reader *r, t_str_builder *b)
{
	while (r->cursor < r->count)
	{
		if (r->buff[r->cursor] == '\n')
		{
			r->cursor += 1;
			ft_builder_print_char (b, 0);
			return (1);
		}
		ft_builder_print_char (b, r->buff[r->cursor]);
		r->cursor += 1;
	}
	return (0);
}

int	get_next_line(const int fd, char **line)
{
	static t_line_reader	reader;
	t_str_builder			builder;

	ft_set_fd (&reader, fd);
	ft_builder_init (&builder, 100);
	while (1)
	{
		if (ft_copy_buff (&reader, &builder))
		{
			*line = builder.data;
			return (1);
		}
		ft_read (&reader);
		if (reader.count == 0)
		{
			ft_builder_print_char (&builder, 0);
			*line = builder.data;
			return (0);
		}
		else if (reader.count == -1)
			break ;
	}
	free (builder.data);
	return (-1);
}
