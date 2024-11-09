import Container from "./og_container";
import cn from "classnames";

type AlertContent = {
  default: {
    message: string;
    linkText: string;
    linkHref: string;
  };
  preview: {
    message: string;
    linkText: string;
    linkHref: string;
  };
};

const alertContent: AlertContent = {
  default: {
    message: "This page is a preview.",
    linkText: "Click here",
    linkHref: "/api/exit-preview",
  },
  preview: {
    message: "Check out the full site!",
    linkText: "click here",
    linkHref: "/",
  },
};

type Props = {
  preview?: boolean;
};

const Alert = ({ preview }: Props) => {
  const { message, linkText, linkHref } = preview
    ? alertContent.preview
    : alertContent.default;

  return (
    <div
      className={cn("border-b transition-colors duration-300", {
        "bg-[#6231F0] border-[#6231F0] text-white": preview,
        "bg-neutral-50 border-neutral-200": !preview,
      })}
    >
      <Container>
        <div className="py-3 text-center">
          <span className="text-sm font-medium">{message}</span>{" "}
          <a
            href={linkHref}
            className={cn(
              "text-sm font-semibold underline duration-300 transition-colors",
              {
                "hover:text-[#9370DB]": preview,
                "hover:text-blue-600": !preview,
              }
            )}
          >
            {linkText}
          </a>
          {!preview && "."}
        </div>
      </Container>
    </div>
  );
};

export default Alert;